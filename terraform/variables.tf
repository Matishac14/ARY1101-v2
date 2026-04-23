variable "alumno_nombre" {
  description = "Nombre del alumno para etiquetado de recursos"
  type        = string
  default     = "Matias Fernandez"
}

variable "alumno_rut" {
  description = "RUT del alumno"
  type        = string
  default     = "20099194k"
}

variable "aws_region" {
  description = "Región de AWS permitida"
  type        = string
  default     = "us-east-1"
}

variable "db_master_password" {
  description = "Password root para la instancia RDS"
  type        = string
  default     = "TechNovaRoot2024!"
  sensitive   = true
}

variable "db_user_password" {
  description = "Password para el usuario de la aplicación technova_user"
  type        = string
  default     = "TechNova2024!"
  sensitive   = true
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}