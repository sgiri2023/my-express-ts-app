import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from "typeorm";
import { User } from "./User";

@Entity({ name: "UserAuditLog" })
export class UserAuditLog {
  @PrimaryGeneratedColumn()
  log_id!: number;

  @ManyToOne(() => User)
  @JoinColumn({ name: "actor_user_id" })
  actor_user!: User;

  @ManyToOne(() => User)
  @JoinColumn({ name: "target_user_id" })
  target_user!: User;

  @Column({ type: "varchar", length: 50 })
  action_type!: string;

  @Column({ type: "text", nullable: true })
  old_value!: string;

  @Column({ type: "text", nullable: true })
  new_value!: string;

  @CreateDateColumn()
  created_at!: Date;
}
