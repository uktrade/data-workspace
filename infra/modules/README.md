### Modules

Modules folders allows us to separate code rather than the flat structure utilised in the rest of this repository. Some standards are set here which it is suggested could be applied to the rest of the repository also.


### Makefile

The Makefile allows for the storing of complex commands with a simple and easy-to-remember interface -

```
make format
```
will run required formatting with terraform and python code and

```
make bump
```
will bump the version number (patch level).




### Required software

You must install [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and [uv](https://docs.astral.sh/uv/getting-started/installation/).
