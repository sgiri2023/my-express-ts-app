import "reflect-metadata";
import { DataSource } from "typeorm";
import { User } from "./entities/User";
import { Role } from "./entities/Role";
import { UserGroup } from "./entities/UserGroup";
import { UserGroupAccess } from "./entities/UserGroupAccess";
import { UserAuditLog } from "./entities/UserAuditLog";
import { GroupAuditLog } from "./entities/GroupAuditLog";
import { UserGroupAccessAuditLog } from "./entities/UserGroupAccessAuditLog";

export const AppDataSource = new DataSource({
  type: "mysql",
  host: "localhost",
  port: 3306,
  username: "root",
  password: "admin",
  database: "UserRoleDBB",
  synchronize: false,
  logging: false,
  dropSchema: false,
  entities: [
     User,
      Role,
      UserGroup,
      UserGroupAccess,
      UserAuditLog,
      GroupAuditLog,
      UserGroupAccessAuditLog
  ]
});
