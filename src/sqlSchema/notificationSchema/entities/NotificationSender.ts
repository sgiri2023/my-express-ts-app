import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { Notification } from './Notification';
import { User } from './User';

@Entity('notification_senders')
export class NotificationSender {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Notification, (notification) => notification.senders, { onDelete: 'CASCADE' })
  notification: Notification;

  @ManyToOne(() => User, (user) => user.sentNotifications, { onDelete: 'CASCADE' })
  sender: User;

  @Column({ type: 'jsonb', default: () => `'{}'` })
  metadata: Record<string, any>;

  @ManyToOne(() => User, { nullable: true })
  created_by?: User;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
