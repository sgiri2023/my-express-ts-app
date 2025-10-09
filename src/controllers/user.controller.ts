import { Request, Response } from "express";
import { UserService } from "../Services/user.service";

const userService = new UserService();

export class UserController {
    async getAll(req: Request, res: Response) {
        const users = await userService.getAllUsers();
        res.json(users);
    }

    async getById(req: Request, res: Response) {
        const id = parseInt(req.params.id);
        const user = await userService.getUserById(id);
        if (!user) return res.status(404).json({ message: "User not found" });
        res.json(user);
    }

    async loginUser(req: Request, res: Response) {
        const email = req.body.email;
        const user = await userService.loginUser(email);
        if (!user) return res.status(404).json({ message: `User not found` });
        if (user.is_active === false) {
        return res.status(403).json({ message: "User account is inactive. Please contact admin." });
    }
        res.json(user);
    }

    async create(req: Request, res: Response) {
        // actorUserId: The logged-in user performing action
        const actorUserId = parseInt(req.body.actor_user_id) || 0;
        const user = await userService.createUser(req.body, actorUserId);
        res.status(201).json(user);
    }

    async update(req: Request, res: Response) {
        const id = parseInt(req.params.id);
        const actorUserId = parseInt(req.body.actor_user_id) || 0;
        const user = await userService.updateUser(id, req.body, actorUserId);
        if (!user) return res.status(404).json({ message: "User not found" });
        res.json(user);
    }

    async delete(req: Request, res: Response) {
        const id = parseInt(req.params.id);
        const actorUserId = parseInt(req.body.actor_user_id) || 0;
        await userService.deleteUser(id, actorUserId);
        res.status(204).send();
    }

    async softDelete(req: Request, res: Response) {
        const id = parseInt(req.params.id);
        const actorUserId = parseInt(req.body.actor_user_id) || 0;
        const isActive  = req.body.isActive;

        const user = await userService.softDeleteUser(id, actorUserId, isActive);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json({ message: "User deactivated successfully" });
    }
}
