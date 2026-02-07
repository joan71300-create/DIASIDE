"""add_initial_schema

Revision ID: 66a0c100b404
Revises: 
Create Date: 2026-02-05 13:58:29.748817

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '66a0c100b404'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(), nullable=True),
        sa.Column('hashed_password', sa.String(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)

    op.create_table(
        'questionnaires',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('age', sa.Integer(), nullable=True),
        sa.Column('gender', sa.String(), nullable=True),
        sa.Column('weight', sa.Float(), nullable=True),
        sa.Column('height', sa.Float(), nullable=True),
        sa.Column('activity_level', sa.String(), nullable=True),
        sa.Column('daily_step_goal', sa.Integer(), nullable=True),
        sa.Column('dietary_preferences', sa.String(), nullable=True),
        sa.Column('diabetes_type', sa.String(), nullable=True),
        sa.Column('target_glucose_min', sa.Float(), nullable=True),
        sa.Column('target_glucose_max', sa.Float(), nullable=True),
        sa.Column('target_hba1c', sa.Float(), nullable=True),
        sa.Column('target_hba1c_date', sa.DateTime(), nullable=True),
        sa.Column('last_lab_hba1c', sa.Float(), nullable=True),
        sa.Column('hba1c_offset', sa.Float(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id')
    )
    op.create_index(op.f('ix_questionnaires_id'), 'questionnaires', ['id'], unique=False)

    op.create_table(
        'daily_stats',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('date', sa.DateTime(), nullable=True),
        sa.Column('steps', sa.Integer(), nullable=True),
        sa.Column('calories_burned', sa.Float(), nullable=True),
        sa.Column('distance_km', sa.Float(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_daily_stats_id'), 'daily_stats', ['id'], unique=False)

    op.create_table(
        'meals',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('timestamp', sa.DateTime(), nullable=True),
        sa.Column('name', sa.String(), nullable=True),
        sa.Column('calories', sa.Float(), nullable=True),
        sa.Column('carbs', sa.Float(), nullable=True),
        sa.Column('protein', sa.Float(), nullable=True),
        sa.Column('fat', sa.Float(), nullable=True),
        sa.Column('image_url', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_meals_id'), 'meals', ['id'], unique=False)

    op.create_table(
        'glucose_entries',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('value', sa.Float(), nullable=True),
        sa.Column('timestamp', sa.DateTime(), nullable=True),
        sa.Column('note', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_glucose_entries_id'), 'glucose_entries', ['id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_glucose_entries_id'), table_name='glucose_entries')
    op.drop_table('glucose_entries')
    op.drop_index(op.f('ix_meals_id'), table_name='meals')
    op.drop_table('meals')
    op.drop_index(op.f('ix_daily_stats_id'), table_name='daily_stats')
    op.drop_table('daily_stats')
    op.drop_index(op.f('ix_questionnaires_id'), table_name='questionnaires')
    op.drop_table('questionnaires')
    op.drop_index(op.f('ix_users_id'), table_name='users')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_.table('users')
