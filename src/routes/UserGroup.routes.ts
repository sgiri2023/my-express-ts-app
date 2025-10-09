import { Router } from "express";
import { UserGroupController } from "../controllers/UserGroup.controller";

const router = Router();

router.get("/", UserGroupController.getAllGroups);
router.get("/:groupId", UserGroupController.getGroupById);
router.post("/", UserGroupController.createGroup);
router.get("/:groupId/users", UserGroupController.getUsersForGroup);

export default router;
