moved {
  from = aws_ecr_repository.vscode
  to   = aws_ecr_repository.tools[0]
}

moved {
  from = aws_ecr_repository.jupyterlab_python
  to   = aws_ecr_repository.tools[1]
}

moved {
  from = aws_ecr_repository.theia
  to   = aws_ecr_repository.tools[2]
}

moved {
  from = aws_ecr_repository.pgadmin
  to   = aws_ecr_repository.tools[3]
}

moved {
  from = aws_ecr_repository.rstudio_rv4
  to   = aws_ecr_repository.tools[4]
}

moved {
  from = aws_ecr_repository.remotedesktop
  to   = aws_ecr_repository.tools[5]
}
