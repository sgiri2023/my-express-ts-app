import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { Notification } from './Notification';
import { User } from './User';
import { NotificationChannel } from './enums/NotificationChannel';

@Entity('notification_recipients')
export class NotificationRecipient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Notification, (notification) => notification.recipients, { onDelete: 'CASCADE' })
  notification: Notification;

  @ManyToOne(() => User, (user) => user.receivedNotifications, { onDelete: 'CASCADE' })
  recipient: User;

  @Column({ type: 'enum', enum: NotificationChannel, default: NotificationChannel.WEB })
  channel: NotificationChannel;

  @Column({ type: 'jsonb', default: () => `'{}'` })
  metadata: Record<string, any>;

  @Column({ default: false })
  is_read: boolean;

  @Column({ default: false })
  is_delivered: boolean;

  @Column({ nullable: true })
  read_at?: Date;

  @Column({ nullable: true })
  delivered_at?: Date;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
