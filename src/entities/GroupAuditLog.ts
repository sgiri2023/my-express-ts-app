import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from "typeorm";
import { User } from "./User";
import { UserGroup } from "./UserGroup";

@Entity({ name: "GroupAuditLog" })
export class GroupAuditLog {
  @PrimaryGeneratedColumn()
  log_id!: number;

  @ManyToOne(() => User)
  @JoinColumn({ name: "actor_user_id" })
  actor_user!: User;

  @ManyToOne(() => UserGroup)
  @JoinColumn({ name: "group_id" })
  group!: UserGroup;

  @Column({ type: "varchar", length: 50 })
  action_type!: string;

  @Column({ type: "text", nullable: true })
  old_value!: string;

  @Column({ type: "text", nullable: true })
  new_value!: string;

  @CreateDateColumn()
  created_at!: Date;
}
