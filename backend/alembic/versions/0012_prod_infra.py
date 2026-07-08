"""Production indexes and audit log

Revision ID: 0012_prod_infra
Revises: 0011_stage5_logic
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0012_prod_infra"
down_revision = "0011_stage5_logic"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.create_table(
		"audit_logs",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id"), nullable=True),
		sa.Column("method", sa.String(length=10), nullable=False),
		sa.Column("path", sa.String(length=500), nullable=False),
		sa.Column("status_code", sa.Integer(), nullable=False),
		sa.Column("entity_type", sa.String(length=50), nullable=True),
		sa.Column("entity_id", sa.String(length=100), nullable=True),
		sa.Column("details_json", sa.Text(), nullable=True),
		sa.Column("ip_address", sa.String(length=45), nullable=True),
		sa.Column("request_id", sa.String(length=64), nullable=True),
		sa.Column(
			"created_at",
			sa.DateTime(timezone=True),
			server_default=sa.text("now()"),
			nullable=False,
		),
	)
	op.create_index("ix_audit_logs_master_id", "audit_logs", ["master_id"])
	op.create_index("ix_audit_logs_created_at", "audit_logs", ["created_at"])
	op.create_index("ix_audit_logs_entity", "audit_logs", ["entity_type", "entity_id"])

	op.create_index(
		"ix_appointments_master_scheduled",
		"appointments",
		["master_id", "scheduled_at"],
		unique=False,
	)
	op.create_index(
		"ix_appointments_master_status",
		"appointments",
		["master_id", "status"],
		unique=False,
	)
	op.create_index(
		"ix_check_history_master_checked",
		"check_history_records",
		["master_id", "checked_at"],
		unique=False,
	)
	op.create_index(
		"ix_notifications_master_read_created",
		"notifications",
		["master_id", "is_read", "created_at"],
		unique=False,
	)


def downgrade() -> None:
	op.drop_index("ix_notifications_master_read_created", table_name="notifications")
	op.drop_index("ix_check_history_master_checked", table_name="check_history_records")
	op.drop_index("ix_appointments_master_status", table_name="appointments")
	op.drop_index("ix_appointments_master_scheduled", table_name="appointments")
	op.drop_index("ix_audit_logs_entity", table_name="audit_logs")
	op.drop_index("ix_audit_logs_created_at", table_name="audit_logs")
	op.drop_index("ix_audit_logs_master_id", table_name="audit_logs")
	op.drop_table("audit_logs")
