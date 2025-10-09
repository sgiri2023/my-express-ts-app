import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from "typeorm";
import { UserGroupAccess } from "./UserGroupAccess";

@Entity({ name: "UserGroups" })
export class UserGroup {
  @PrimaryGeneratedColumn()
  group_id!: number;

  @Column({ type: "varchar", length: 100, unique: true })
  group_name!: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  description!: string;

  @Column({ type: "boolean", default: true })
  is_active!: boolean;

  @CreateDateColumn()
  created_at!: Date;

  @UpdateDateColumn()
  updated_at!: Date;

  @OneToMany(() => UserGroupAccess, uga => uga.group)
  userAccess!: UserGroupAccess[];
}
