import mock

import pytest
from bs4 import BeautifulSoup

from django.contrib.auth.models import Permission
from django.test import override_settings, Client
from django.urls import reverse

from dataworkspace.tests.common import (
    BaseTestCase,
    get_response_csp_as_set,
    get_http_sso_data,
)
from dataworkspace.tests.factories import UserFactory


class TestSupportView(BaseTestCase):
    def test_create_support_request_invalid_email(self):
        response = self._authenticated_post(
            reverse('support'), {'email': 'x', 'message': 'test message'}
        )
        self.assertContains(response, 'Enter a valid email address')

    def test_create_support_request_invalid_message(self):
        response = self._authenticated_post(
            reverse('support'), {'email': 'noreply@example.com', 'message': ''}
        )
        self.assertContains(response, 'This field is required')

    @mock.patch('dataworkspace.apps.core.views.create_support_request')
    def test_create_support_request(self, mock_create_request):
        mock_create_request.return_value = 999
        response = self._authenticated_post(
            reverse('support'),
            data={'email': 'noreply@example.com', 'message': 'A test message'},
            post_format='multipart',
        )
        self.assertContains(
            response,
            'Your request has been received. Your reference is: '
            '<strong>999</strong>.',
            html=True,
        )
        mock_create_request.assert_called_once()

    @mock.patch('dataworkspace.apps.core.views.create_support_request')
    def test_create_tagged_support_request(self, mock_create_request):
        mock_create_request.return_value = 999
        response = self._authenticated_post(
            reverse('support') + '?tag=data-request',
            data={'email': 'noreply@example.com', 'message': 'A test message'},
            post_format='multipart',
        )
        self.assertContains(
            response,
            'Your request has been received. Your reference is: '
            '<strong>999</strong>.',
            html=True,
        )
        mock_create_request.assert_called_once_with(
            mock.ANY, 'noreply@example.com', 'A test message', tag='data_request'
        )

    @mock.patch('dataworkspace.apps.core.views.create_support_request')
    def test_create_tagged_support_request_unknown_tag(self, mock_create_request):
        mock_create_request.return_value = 999
        response = self._authenticated_post(
            reverse('support') + '?tag=invalid-tag',
            data={'email': 'noreply@example.com', 'message': 'A test message'},
            post_format='multipart',
        )
        self.assertContains(
            response,
            'Your request has been received. Your reference is: '
            '<strong>999</strong>.',
            html=True,
        )
        mock_create_request.assert_called_once_with(
            mock.ANY, 'noreply@example.com', 'A test message', tag=None
        )


def test_csp_on_files_endpoint_includes_s3(client):
    response = client.get(reverse('files'))
    assert response.status_code == 200

    policies = get_response_csp_as_set(response)
    assert (
        "connect-src dataworkspace.test:8000 https://s3.eu-west-2.amazonaws.com"
        in policies
    )


@pytest.mark.parametrize(
    "request_client", ('client', 'staff_client'), indirect=["request_client"]
)
def test_header_links(request_client):
    response = request_client.get(reverse("root"))

    soup = BeautifulSoup(response.content.decode(response.charset))
    header_links = soup.find("header").find_all("a")

    link_labels = [(link.get_text().strip(), link.get('href')) for link in header_links]

    expected_links = [
        ("Data Workspace", "http://dataworkspace.test:8000/"),
        ("Switch to Data Hub", "https://www.datahub.trade.gov.uk/"),
        ("Home", "http://dataworkspace.test:8000/"),
        ("Tools", "/tools/"),
        ("About", "/about/"),
        ("Support and feedback", "/support-and-feedback/"),
        (
            "Help centre (opens in a new tab)",
            "https://data-services-help.trade.gov.uk/data-workspace",
        ),
    ]

    assert link_labels == expected_links


@pytest.mark.parametrize(
    "request_client", ("client", "staff_client"), indirect=["request_client"]
)
def test_footer_links(request_client):
    response = request_client.get(reverse("root"))

    soup = BeautifulSoup(response.content.decode(response.charset))
    footer_links = soup.find("footer").find_all("a")

    link_labels = [(link.get_text().strip(), link.get('href')) for link in footer_links]

    expected_links = [
        ('Home', 'http://dataworkspace.test:8000/'),
        ("Tools", "/tools/"),
        ('About', '/about/'),
        ("Support and feedback", "/support-and-feedback/"),
        (
            'Help centre (opens in a new tab)',
            'https://data-services-help.trade.gov.uk/data-workspace',
        ),
        (
            'Accessibility statement',
            (
                'https://data-services-help.trade.gov.uk/data-workspace/how-articles/data-workspace-basics/'
                'data-workspace-accessibility-statement/'
            ),
        ),
        (
            'Privacy Policy',
            'https://workspace.trade.gov.uk/working-at-dit/policies-and-guidance/data-workspace-privacy-policy',
        ),
        (
            'Open Government Licence v3.0',
            'https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/',
        ),
        (
            '© Crown copyright',
            'https://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/'
            'uk-government-licensing-framework/crown-copyright/',
        ),
    ]

    assert link_labels == expected_links


@pytest.mark.parametrize(
    "has_quicksight_access, expected_href, expected_text",
    (
        (True, "/tools/quicksight/redirect", "Open AWS QuickSight"),
        (False, "/support-and-feedback/", "Request access to AWS QuickSight"),
    ),
)
@override_settings(QUICKSIGHT_SSO_URL='https://quicksight')
@pytest.mark.django_db
def test_quicksight_link_only_shown_to_user_with_permission(
    has_quicksight_access, expected_href, expected_text
):
    user = UserFactory.create(is_staff=False, is_superuser=False)
    if has_quicksight_access:
        perm = Permission.objects.get(codename='access_quicksight')
        user.user_permissions.add(perm)
    user.save()
    client = Client(**get_http_sso_data(user))

    response = client.get(reverse("applications:tools"))

    soup = BeautifulSoup(response.content.decode(response.charset))
    quicksight_link = soup.find('a', href=True, text=expected_text)
    assert quicksight_link.get('href') == expected_href


@pytest.mark.parametrize(
    "has_appstream_update, expected_href, expected_text",
    (
        (True, "https://appstream", "Open SPSS / STATA"),
        (False, "/support-and-feedback/", "Request access to SPSS / STATA"),
    ),
)
@override_settings(APPSTREAM_URL='https://appstream')
@pytest.mark.django_db
def test_appstream_link_only_shown_to_user_with_permission(
    has_appstream_update, expected_href, expected_text
):
    user = UserFactory.create(is_staff=False, is_superuser=False)
    if has_appstream_update:
        perm = Permission.objects.get(codename='access_appstream')
        user.user_permissions.add(perm)
    user.save()
    client = Client(**get_http_sso_data(user))

    response = client.get(reverse("applications:tools"))

    soup = BeautifulSoup(response.content.decode(response.charset))
    quicksight_link = soup.find('a', href=True, text=expected_text)
    assert quicksight_link.get('href') == expected_href
