"""Stage 5: appointment status, review links, onboarding flag

Revision ID: 0011_stage5_logic
Revises: 0010_comms_notify
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0011_stage5_logic"
down_revision = "0010_comms_notify"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column(
		"appointments",
		sa.Column("status", sa.String(length=20), nullable=False, server_default="scheduled"),
	)
	op.add_column(
		"masters",
		sa.Column("onboarding_completed", sa.Boolean(), nullable=False, server_default=sa.false()),
	)
	op.add_column(
		"master_reviews",
		sa.Column("master_id", sa.Integer(), nullable=True),
	)
	op.add_column(
		"master_reviews",
		sa.Column("appointment_id", sa.Integer(), nullable=True),
	)
	op.create_foreign_key(
		"fk_master_reviews_master_id",
		"master_reviews",
		"masters",
		["master_id"],
		["id"],
	)
	op.create_foreign_key(
		"fk_master_reviews_appointment_id",
		"master_reviews",
		"appointments",
		["appointment_id"],
		["id"],
	)
	op.create_index("ix_master_reviews_master_id", "master_reviews", ["master_id"])
	op.create_index("ix_master_reviews_appointment_id", "master_reviews", ["appointment_id"], unique=True)

	op.execute(
		"""
		UPDATE appointments AS a
		SET status = 'no_show'
		FROM visit_results AS v
		WHERE v.appointment_id = a.id AND v.punctuality = 'noShow'
		"""
	)
	op.execute(
		"""
		UPDATE appointments AS a
		SET status = 'completed'
		FROM visit_results AS v
		WHERE v.appointment_id = a.id AND v.punctuality != 'noShow'
		"""
	)


def downgrade() -> None:
	op.drop_index("ix_master_reviews_appointment_id", table_name="master_reviews")
	op.drop_index("ix_master_reviews_master_id", table_name="master_reviews")
	op.drop_constraint("fk_master_reviews_appointment_id", "master_reviews", type_="foreignkey")
	op.drop_constraint("fk_master_reviews_master_id", "master_reviews", type_="foreignkey")
	op.drop_column("master_reviews", "appointment_id")
	op.drop_column("master_reviews", "master_id")
	op.drop_column("masters", "onboarding_completed")
	op.drop_column("appointments", "status")
