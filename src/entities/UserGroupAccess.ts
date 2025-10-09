import { Entity, PrimaryGeneratedColumn, ManyToOne, JoinColumn, Column, CreateDateColumn } from "typeorm";
import { User } from "./User";
import { UserGroup } from "./UserGroup";
import { Role } from "./Role";

@Entity({ name: "UserGroupAccess" })
export class UserGroupAccess {
  @PrimaryGeneratedColumn()
  user_group_access_id!: number;

  @ManyToOne(() => User)
  @JoinColumn({ name: "user_id" })
  user!: User;

  @ManyToOne(() => UserGroup)
  @JoinColumn({ name: "group_id" })
  group!: UserGroup;

  @ManyToOne(() => Role)
  @JoinColumn({ name: "role_id" })
  role!: Role;

  @CreateDateColumn()
  assigned_at!: Date;

  @Column({ type: "boolean", default: true })
  is_active!: boolean;
}
