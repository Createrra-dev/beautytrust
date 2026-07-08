"""Community read/close, devices, notifications, support attachments

Revision ID: 0010_comms_notify
Revises: 0009_tariff_subscriptions
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0010_comms_notify"
down_revision = "0009_tariff_subscriptions"
branch_labels = None
depends_on = None


def upgrade() -> None:
	bind = op.get_bind()
	inspector = sa.inspect(bind)
	tables = set(inspector.get_table_names())

	topic_columns = {c["name"] for c in inspector.get_columns("community_topics")}
	if "author_master_id" not in topic_columns:
		op.add_column("community_topics", sa.Column("author_master_id", sa.Integer(), nullable=True))
		op.create_foreign_key(
			"fk_community_topics_author_master_id",
			"community_topics",
			"masters",
			["author_master_id"],
			["id"],
		)
		op.create_index("ix_community_topics_author_master_id", "community_topics", ["author_master_id"])
	if "is_closed" not in topic_columns:
		op.add_column(
			"community_topics",
			sa.Column("is_closed", sa.Boolean(), nullable=False, server_default=sa.text("false")),
		)

	message_columns = {c["name"] for c in inspector.get_columns("community_messages")}
	if "author_master_id" not in message_columns:
		op.add_column("community_messages", sa.Column("author_master_id", sa.Integer(), nullable=True))
		op.create_foreign_key(
			"fk_community_messages_author_master_id",
			"community_messages",
			"masters",
			["author_master_id"],
			["id"],
		)
		op.create_index("ix_community_messages_author_master_id", "community_messages", ["author_master_id"])

	if "community_topic_reads" not in tables:
		op.create_table(
			"community_topic_reads",
			sa.Column("id", sa.Integer(), primary_key=True),
			sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id"), nullable=False),
			sa.Column("topic_id", sa.Integer(), sa.ForeignKey("community_topics.id"), nullable=False),
			sa.Column("last_read_at", sa.DateTime(timezone=True), nullable=False),
			sa.UniqueConstraint("master_id", "topic_id", name="uq_community_topic_reads_master_topic"),
		)
		op.create_index("ix_community_topic_reads_master_id", "community_topic_reads", ["master_id"])
		op.create_index("ix_community_topic_reads_topic_id", "community_topic_reads", ["topic_id"])

	support_msg_columns = {c["name"] for c in inspector.get_columns("support_messages")}
	if "attachment_path" not in support_msg_columns:
		op.add_column("support_messages", sa.Column("attachment_path", sa.String(length=500), nullable=True))
		op.add_column("support_messages", sa.Column("attachment_name", sa.String(length=255), nullable=True))

	tables = set(sa.inspect(bind).get_table_names())
	if "device_tokens" not in tables:
		op.create_table(
			"device_tokens",
			sa.Column("id", sa.Integer(), primary_key=True),
			sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id"), nullable=False),
			sa.Column("token", sa.String(length=512), nullable=False),
			sa.Column("platform", sa.String(length=20), nullable=False, server_default="ios"),
			sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
			sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
			sa.UniqueConstraint("token", name="uq_device_tokens_token"),
		)
		op.create_index("ix_device_tokens_master_id", "device_tokens", ["master_id"])

	if "notifications" not in tables:
		op.create_table(
			"notifications",
			sa.Column("id", sa.Integer(), primary_key=True),
			sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id"), nullable=False),
			sa.Column("title", sa.String(length=200), nullable=False),
			sa.Column("body", sa.Text(), nullable=False),
			sa.Column("kind", sa.String(length=50), nullable=False, server_default="general"),
			sa.Column("payload_json", sa.Text(), nullable=True),
			sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.text("false")),
			sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
		)
		op.create_index("ix_notifications_master_id", "notifications", ["master_id"])


def downgrade() -> None:
	op.drop_table("notifications")
	op.drop_table("device_tokens")
	op.drop_column("support_messages", "attachment_name")
	op.drop_column("support_messages", "attachment_path")
	op.drop_table("community_topic_reads")
	op.drop_constraint("fk_community_messages_author_master_id", "community_messages", type_="foreignkey")
	op.drop_index("ix_community_messages_author_master_id", table_name="community_messages")
	op.drop_column("community_messages", "author_master_id")
	op.drop_constraint("fk_community_topics_author_master_id", "community_topics", type_="foreignkey")
	op.drop_index("ix_community_topics_author_master_id", table_name="community_topics")
	op.drop_column("community_topics", "author_master_id")
	op.drop_column("community_topics", "is_closed")
