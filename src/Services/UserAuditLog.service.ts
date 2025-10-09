import { AppDataSource } from "../data-source";
import { UserAuditLog } from "../entities/UserAuditLog";

export class UserAuditLogService {
  private auditLogRepo = AppDataSource.getRepository(UserAuditLog);

  async createLog(data: Partial<UserAuditLog>): Promise<UserAuditLog> {
    const log = this.auditLogRepo.create(data);
    return await this.auditLogRepo.save(log);
  }

  async getLogs(): Promise<UserAuditLog[]> {
    return await this.auditLogRepo.find({
      relations: ["actor_user", "target_user"],
      order: { created_at: "DESC" }
    });
  }

  async getLogById(id: number): Promise<UserAuditLog | null> {
    return await this.auditLogRepo.findOne({
      where: { log_id: id },
      relations: ["actor_user", "target_user"]
    });
  }
}
