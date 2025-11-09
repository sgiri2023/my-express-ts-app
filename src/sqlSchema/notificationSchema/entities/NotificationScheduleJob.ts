import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { NotificationTemplate } from './NotificationTemplate';

@Entity('notification_schedule_jobs')
export class NotificationScheduleJob {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => NotificationTemplate, { onDelete: 'SET NULL' })
  template: NotificationTemplate;

  @Column({ type: 'jsonb', default: () => `'{}'` })
  payload: Record<string, any>;

  @Column({ type: 'timestamp' })
  scheduled_for: Date;

  @Column({ type: 'timestamp', nullable: true })
  executed_at?: Date;

  @Column({ default: 'PENDING' })
  status: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
