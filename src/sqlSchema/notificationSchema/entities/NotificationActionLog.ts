import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn } from 'typeorm';
import { Notification } from './Notification';
import { User } from './User';
import { NotificationChannel } from './enums/NotificationChannel';
import { NotificationActionType } from './enums/NotificationActionType';

@Entity('notification_action_logs')
export class NotificationActionLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Notification, { onDelete: 'CASCADE' })
  notification: Notification;

  @ManyToOne(() => User, (user) => user.actions, { onDelete: 'SET NULL' })
  acted_by?: User;

  @Column({ type: 'enum', enum: NotificationChannel, nullable: true })
  channel?: NotificationChannel;

  @Column({ type: 'enum', enum: NotificationActionType })
  action_type: NotificationActionType;

  @Column({ nullable: true })
  provider?: string;

  @Column({ nullable: true })
  provider_message_id?: string;

  @Column({ type: 'jsonb', nullable: true })
  action_metadata?: Record<string, any>;

  @Column({ nullable: true })
  remarks?: string;

  @CreateDateColumn()
  created_at: Date;
}
