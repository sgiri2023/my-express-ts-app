import { Router } from "express";
import { UserController } from "../controllers/user.controller";

const router = Router();
const userController = new UserController();

router.get("/", userController.getAll.bind(userController));
router.get("/:id", userController.getById.bind(userController));
router.post("/login", userController.loginUser.bind(userController));
router.post("/", userController.create.bind(userController));
router.put("/:id", userController.update.bind(userController));
router.put("/activate-deactivate/:id", userController.softDelete.bind(userController));
router.delete("/:id", userController.delete.bind(userController));

export default router;
