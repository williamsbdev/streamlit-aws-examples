resource "aws_vpc" "streamlit" {
  cidr_block = "10.0.0.0/19"
  tags = {
    Name = "streamlit-example"
  }
}

resource "aws_subnet" "public_az_1" {
  vpc_id            = aws_vpc.streamlit.id
  cidr_block        = "10.0.0.0/22"
  availability_zone = "${var.region}a"
  tags = {
    Name = "streamlit-example-public-az-1"
  }
}

resource "aws_subnet" "public_az_2" {
  vpc_id            = aws_vpc.streamlit.id
  cidr_block        = "10.0.4.0/22"
  availability_zone = "${var.region}b"
  tags = {
    Name = "streamlit-example-public-az-2"
  }
}

resource "aws_subnet" "public_az_3" {
  vpc_id            = aws_vpc.streamlit.id
  cidr_block        = "10.0.8.0/22"
  availability_zone = "${var.region}c"
  tags = {
    Name = "streamlit-example-public-az-3"
  }
}

resource "aws_internet_gateway" "public_internet_gateway" {
  vpc_id = aws_vpc.streamlit.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.streamlit.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_internet_gateway.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_route_table_az_1" {
  subnet_id      = aws_subnet.public_az_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_az_2" {
  subnet_id      = aws_subnet.public_az_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_az_3" {
  subnet_id      = aws_subnet.public_az_3.id
  route_table_id = aws_route_table.public_route_table.id
}
