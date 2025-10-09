import { Request, Response } from "express";
import { UserAuditLogService } from "../Services/UserAuditLog.service";

const auditLogService = new UserAuditLogService();

export class UserAuditLogController {
  static async createLog(req: Request, res: Response) {
    try {
      const log = await auditLogService.createLog(req.body);
      return res.status(201).json(log);
    } catch (error) {
      return res.status(500).json({ message: "Error creating log", error });
    }
  }

  static async getLogs(req: Request, res: Response) {
    try {
      const logs = await auditLogService.getLogs();
      return res.json(logs);
    } catch (error) {
      return res.status(500).json({ message: "Error fetching logs", error });
    }
  }

  static async getLogById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const log = await auditLogService.getLogById(Number(id));
      if (!log) {
        return res.status(404).json({ message: "Log not found" });
      }
      return res.json(log);
    } catch (error) {
      return res.status(500).json({ message: "Error fetching log", error });
    }
  }
}
