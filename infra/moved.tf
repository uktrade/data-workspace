moved {
    from = aws_ecr_repository.vscode
    to = aws_ecr_repository.tools[0]
}
