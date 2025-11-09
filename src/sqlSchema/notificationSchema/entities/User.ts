import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Role } from './Role';
import { Notification } from './Notification';
import { NotificationSender } from './NotificationSender';
import { NotificationRecipient } from './NotificationRecipient';
import { NotificationActionLog } from './NotificationActionLog';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  full_name: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @ManyToOne(() => Role, (role) => role.users, { onDelete: 'SET NULL' })
  role: Role;

  @Column({ default: true })
  is_active: boolean;

  @Column({ type: 'jsonb', nullable: true })
  metadata?: Record<string, any>;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  @OneToMany(() => NotificationSender, (sender) => sender.sender)
  sentNotifications: NotificationSender[];

  @OneToMany(() => NotificationRecipient, (recipient) => recipient.recipient)
  receivedNotifications: NotificationRecipient[];

  @OneToMany(() => NotificationActionLog, (log) => log.acted_by)
  actions: NotificationActionLog[];
}
