# Dynamic string on parameter store
resource "aws_ssm_parameter" "dynamic_string" {
    name = "/dynamic_string"
    type = "String"
    value = var.default_dynamic_string
}

# For Lambda function
## Package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}
## IAM Role
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

## Attach basic execution policy to lambda role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


## Create Lambda function
resource "aws_lambda_function" "dynamic_string_website_lambda" {
  function_name = "dynamic_string_website"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler       = "app.handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_exec_role.arn
}

## Grant Lambda permission to read and write from SSM Parameter Store
resource "aws_iam_role_policy" "ssm_read_policy" {
  name = "SSMReadPolicy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["ssm:GetParameter", "ssm:PutParameter"],
      Resource = [aws_ssm_parameter.dynamic_string.arn, "${aws_ssm_parameter.dynamic_string.arn}/*"]
    }]
  })
}

# Create Rest API Gateway
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "website-api"
  description = "API Gateway for Lambda integration"
}

## Create Get Method on root
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = false
}

## Integrate Method with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.dynamic_string_website_lambda.invoke_arn
}

# Grant API Gateway permission to invoke Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dynamic_string_website_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

# Deploy the API
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
}

# Create a stage for the deployment
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = var.stage_name
}