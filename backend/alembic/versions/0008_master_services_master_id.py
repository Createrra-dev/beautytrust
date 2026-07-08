"""Add master_id to master_services

Revision ID: 0008_master_services_master_id
Revises: 0007_payment_attempts_indexes
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0008_master_services_master_id"
down_revision = "0007_payment_attempts_indexes"
branch_labels = None
depends_on = None


def upgrade() -> None:
	bind = op.get_bind()
	inspector = sa.inspect(bind)
	columns = {column["name"] for column in inspector.get_columns("master_services")}
	indexes = {index["name"] for index in inspector.get_indexes("master_services")}
	uniques = {unique["name"] for unique in inspector.get_unique_constraints("master_services")}

	if "master_id" not in columns:
		op.add_column("master_services", sa.Column("master_id", sa.Integer(), nullable=True))
		op.create_foreign_key(
			"fk_master_services_master_id_masters",
			"master_services",
			"masters",
			["master_id"],
			["id"],
		)

	if "ix_master_services_master_id" not in indexes:
		op.create_index("ix_master_services_master_id", "master_services", ["master_id"], unique=False)

	# Drop global unique on name if present (constraint or unique index).
	# Constraint drop also removes the backing index — do not drop twice.
	dropped_name_unique = False
	if "master_services_name_key" in uniques:
		op.drop_constraint("master_services_name_key", "master_services", type_="unique")
		dropped_name_unique = True
	elif "uq_master_services_name" in uniques:
		op.drop_constraint("uq_master_services_name", "master_services", type_="unique")
		dropped_name_unique = True

	if not dropped_name_unique:
		for index in inspector.get_indexes("master_services"):
			if index.get("unique") and index.get("column_names") == ["name"]:
				op.drop_index(index["name"], table_name="master_services")


def downgrade() -> None:
	bind = op.get_bind()
	inspector = sa.inspect(bind)
	columns = {column["name"] for column in inspector.get_columns("master_services")}
	indexes = {index["name"] for index in inspector.get_indexes("master_services")}

	if "ix_master_services_master_id" in indexes:
		op.drop_index("ix_master_services_master_id", table_name="master_services")

	if "master_id" in columns:
		op.drop_constraint("fk_master_services_master_id_masters", "master_services", type_="foreignkey")
		op.drop_column("master_services", "master_id")

	op.create_unique_constraint("master_services_name_key", "master_services", ["name"])
