import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { NotificationType } from './enums/NotificationType';

@Entity('notification_templates')
export class NotificationTemplate {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  name: string;

  @Column({ type: 'enum', enum: NotificationType })
  type: NotificationType;

  @Column()
  title_template: string;

  @Column()
  message_template: string;

  @Column({ type: 'jsonb', default: () => `'{}'` })
  default_metadata: Record<string, any>;

  @Column({ default: false })
  is_actionable: boolean;

  @Column({ type: 'jsonb', default: () => `'{}'` })
  action_config: Record<string, any>;

  @Column({ nullable: true })
  default_duration?: string;

  @Column({ default: false })
  auto_schedule: boolean;

  @Column({ default: false })
  is_deleted: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
