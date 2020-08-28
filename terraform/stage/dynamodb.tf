resource "aws_dynamodb_table" "counter-db" {
  name         = "crc-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "CounterID"
  attribute {
    name = "CounterID"
    type = "S"
  }
}
