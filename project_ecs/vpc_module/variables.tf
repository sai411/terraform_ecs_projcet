//variable "key" {}  

variable "az" {

    default = ["us-east-1a", "us-east-1b"] 
}

variable "vpccidr" {

    default = "192.0.0.0/16"
  
}

variable "subIP" {
  
  default = ["192.0.1.0/24"]

}

variable "sub_pvt" {

  default = ["192.0.3.0/24"]
  
}

variable "ami_id" {

  default = "ami-06aa3f7caf3a30282"
  
}
