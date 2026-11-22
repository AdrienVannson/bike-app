variable "db_deletion_protection" {
  description = "Protect the database from deletion, and take a final snapshot if it is deleted anyway."
  type        = bool
}

variable "db_backup_retention_days" {
  description = "Number of days the automated database backups are kept."
  type        = number
}
