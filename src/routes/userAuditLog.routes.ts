import { Router } from "express";
import { UserAuditLogController } from "../controllers/UserAuditLog.controller";

const router = Router();

router.post("/", UserAuditLogController.createLog);
router.get("/", UserAuditLogController.getLogs);
router.get("/:id", UserAuditLogController.getLogById);

export default router;
