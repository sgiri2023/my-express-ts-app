import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from "typeorm";
import { UserGroupAccess } from "./UserGroupAccess";

@Entity({ name: "Roles" })
export class Role {
  @PrimaryGeneratedColumn()
  role_id!: number;

  @Column({ type: "varchar", length: 50, unique: true })
  role_name!: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  description!: string;

  @CreateDateColumn()
  created_at!: Date;

  @UpdateDateColumn()
  updated_at!: Date;

  @OneToMany(() => UserGroupAccess, uga => uga.role)
  userGroupAccess!: UserGroupAccess[];
}
