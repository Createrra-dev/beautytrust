"""visit behavior details

Revision ID: 0014_visit_behavior
Revises: 0013_profile_ext
Create Date: 2026-07-09
"""

from alembic import op
import sqlalchemy as sa

revision = "0014_visit_behavior"
down_revision = "0013_profile_ext"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column(
		"visit_results",
		sa.Column("had_behavior_issues", sa.Boolean(), nullable=False, server_default=sa.false()),
	)
	op.add_column(
		"visit_results",
		sa.Column("was_unfriendly", sa.Boolean(), nullable=False, server_default=sa.false()),
	)
	op.add_column(
		"visit_results",
		sa.Column("threatened_complaints", sa.Boolean(), nullable=False, server_default=sa.false()),
	)
	op.add_column(
		"visit_results",
		sa.Column("demanded_discount", sa.Boolean(), nullable=False, server_default=sa.false()),
	)
	op.add_column(
		"visit_results",
		sa.Column("stole_from_salon", sa.Boolean(), nullable=False, server_default=sa.false()),
	)

	op.execute(
		"UPDATE visit_results SET had_behavior_issues = had_scandal WHERE had_scandal = TRUE"
	)

	op.alter_column("visit_results", "had_behavior_issues", server_default=None)


def downgrade() -> None:
	op.drop_column("visit_results", "stole_from_salon")
	op.drop_column("visit_results", "demanded_discount")
	op.drop_column("visit_results", "threatened_complaints")
	op.drop_column("visit_results", "was_unfriendly")
	op.drop_column("visit_results", "had_behavior_issues")
