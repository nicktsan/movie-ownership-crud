# Setup for put_movie_ownership lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.sourceDir
  output_path = var.outputPath
}
