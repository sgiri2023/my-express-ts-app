import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from "typeorm";
import { UserGroupAccess } from "./UserGroupAccess";
import { UserAuditLog } from "./UserAuditLog";

@Entity({ name: "Users" })
export class User {
  @PrimaryGeneratedColumn()
  user_id!: number;

  @Column({ type: "varchar", length: 100, unique: true })
  username!: string;

  @Column({ type: "varchar", length: 150, unique: true })
  email!: string;

  @Column({ type: "varchar", length: 255 })
  password_hash!: string;

  @Column({ type: "boolean", default: false })
  is_global_admin!: boolean;

  @Column({ type: "boolean", default: true })
  is_active!: boolean;

  @CreateDateColumn()
  created_at!: Date;

  @UpdateDateColumn()
  updated_at!: Date;

  @Column({ type: "timestamp", nullable: true })
  last_login?: Date;

  @OneToMany(() => UserGroupAccess, uga => uga.user)
  groupAccess!: UserGroupAccess[];

  @OneToMany(() => UserAuditLog, log => log.actor_user)
  auditLogs!: UserAuditLog[];
}
