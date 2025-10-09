import { Request, Response } from "express";
import { UserGroupAccessService } from "../Services/userGroupAccess.service";

const accessService = new UserGroupAccessService();

export class UserGroupAccessController {

  // GET /user-group-access
  async getAll(req: Request, res: Response) {
    try {
      const data = await accessService.getAll();
      res.status(200).json(data);
    } catch (err) {
      res.status(500).json({ error: (err as Error).message });
    }
  }

  // GET /user-group-access/:id
  async getById(req: Request, res: Response) {
    const id = Number(req.params.id);
    try {
      const data = await accessService.getById(id);
      if (!data) return res.status(404).json({ message: "Not found" });
      res.status(200).json(data);
    } catch (err) {
      res.status(500).json({ error: (err as Error).message });
    }
  }

  async getGroupsForUser(req: Request, res: Response) {
        const userId = parseInt(req.params.id);
        if (isNaN(userId)) {
            return res.status(400).json({ message: "Invalid user id" });
        }

        try {
            const groups = await accessService.getGroupsForUser(userId);
            return res.status(200).json(groups);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

  // POST /user-group-access/assign
  async assignRole(req: Request, res: Response) {
    const { userId, groupId, roleId, actorUserId } = req.body;
    try {
      const access = await accessService.assignRole(userId, groupId, roleId, actorUserId);
      res.status(201).json(access);
    } catch (err) {
      res.status(400).json({ error: (err as Error).message });
    }
  }

  // PATCH /user-group-access/:id/change-role
  async changeRole(req: Request, res: Response) {
    const id = Number(req.params.id);
    const { newRoleId, actorUserId } = req.body;
    try {
      const updated = await accessService.changeRole(id, newRoleId, actorUserId);
      if (!updated) return res.status(404).json({ message: "Access not found" });
      res.status(200).json(updated);
    } catch (err) {
      res.status(400).json({ error: (err as Error).message });
    }
  }

  // DELETE /user-group-access/:id
  async removeRole(req: Request, res: Response) {
    const id = Number(req.params.id);
    const { actorUserId } = req.body;
    try {
      await accessService.removeRole(id, actorUserId);
      res.status(204).send();
    } catch (err) {
      res.status(400).json({ error: (err as Error).message });
    }
  }
}
