import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from "typeorm";
import { User } from "./User";
import { UserGroup } from "./UserGroup";

@Entity({ name: "UserGroupAccessAuditLog" })
export class UserGroupAccessAuditLog {
  @PrimaryGeneratedColumn()
  log_id!: number;

  @ManyToOne(() => User)
  @JoinColumn({ name: "actor_user_id" })
  actor_user!: User;

  @ManyToOne(() => User)
  @JoinColumn({ name: "target_user_id" })
  target_user!: User;

  @ManyToOne(() => UserGroup)
  @JoinColumn({ name: "group_id" })
  group!: UserGroup;

  @Column({ type: "varchar", length: 50 })
  action_type!: string;

  @Column({ type: "varchar", length: 50, nullable: true })
  old_role!: string;

  @Column({ type: "varchar", length: 50, nullable: true })
  new_role!: string;

  @CreateDateColumn()
  created_at!: Date;
}
