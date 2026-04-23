# TechNova Migration - AWS Learner Lab Edition

**Alumno:** Matias Fernandez  
**Proyecto:** ARY1101 Evaluación 2

## Requisitos Previos
1. Tener el AWS Learner Lab activo.
2. Copiar las credenciales de la consola (AWS Suite) al terminal.
3. Terraform instalado.

## Despliegue
1. Entrar a `scripts/`.
2. Ejecutar `./01_deploy.sh`.
3. Esperar 10-12 minutos (RDS tarda en provisionar y el EC2 en descargar Docker images).

## Validación
Ejecutar `./02_validate.sh` para comprobar los endpoints.

## Acceso Debug
Usar el comando de salida de Terraform:
`aws ssm start-session --target <id_instancia> --region us-east-1`