import { Router } from "express";
import { UserGroupAccessController } from "../controllers/UserGroupAccessController";

const router = Router();
const controller = new UserGroupAccessController();

router.get("/", controller.getAll.bind(controller));
router.get("/:id", controller.getById.bind(controller));
router.post("/assign", controller.assignRole.bind(controller));
router.patch("/:id/change-role", controller.changeRole.bind(controller));
router.delete("/:id", controller.removeRole.bind(controller));
// Get list of group accessible to user
router.get("/users/:id/groups", controller.getGroupsForUser.bind(controller));

export default router;
