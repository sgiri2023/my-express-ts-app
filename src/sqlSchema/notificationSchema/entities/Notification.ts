import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { NotificationTemplate } from './NotificationTemplate';
import { NotificationType } from './enums/NotificationType';
import { NotificationActionStatus } from './enums/NotificationActionStatus';
import { User } from './User';
import { NotificationSender } from './NotificationSender';
import { NotificationRecipient } from './NotificationRecipient';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => NotificationTemplate, { onDelete: 'SET NULL' })
  template: NotificationTemplate;

  @Column({ type: 'enum', enum: NotificationType })
  type: NotificationType;

  @Column()
  title: string;

  @Column()
  message: string;

  @Column({ type: 'jsonb', default: () => `'{}'` })
  metadata: Record<string, any>;

  @Column({ default: false })
  is_actionable: boolean;

  @Column({ type: 'jsonb', default: () => `'{}'` })
  action_config: Record<string, any>;

  @Column({ type: 'enum', enum: NotificationActionStatus, default: NotificationActionStatus.NONE })
  action_status: NotificationActionStatus;

  @ManyToOne(() => User, { onDelete: 'SET NULL' })
  action_taken_by?: User;

  @Column({ nullable: true })
  action_taken_at?: Date;

  @Column({ type: 'timestamp', default: () => 'NOW()' })
  start_time: Date;

  @Column({ type: 'timestamp', nullable: true })
  end_time?: Date;

  @Column({ default: false })
  is_expired: boolean;

  @Column({ default: false })
  is_deleted: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  @OneToMany(() => NotificationSender, (sender) => sender.notification)
  senders: NotificationSender[];

  @OneToMany(() => NotificationRecipient, (recipient) => recipient.notification)
  recipients: NotificationRecipient[];
}
