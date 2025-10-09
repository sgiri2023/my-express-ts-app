import { Request, Response } from "express";
import { UserGroupService } from "../Services/userGroup.service";

const service = new UserGroupService();

export class UserGroupController {
    static getAllGroups = async (req: Request, res: Response) => {
        const groups = await service.getAllGroups();
        res.json(groups);
    };

    static getGroupById = async (req: Request, res: Response) => {
        const groupId = parseInt(req.params.groupId);
        const group = await service.getGroupById(groupId);
        if (!group) return res.status(404).json({ message: "Group not found" });
        res.json(group);
    };

    static createGroup = async (req: Request, res: Response) => {
        const actorUserId = parseInt(req.body.actorUserId);
        const groupData = req.body;
        const group = await service.createGroup(groupData, actorUserId);
        res.status(201).json(group);
    };

    static getUsersForGroup = async (req: Request, res: Response) => {
        const groupId = parseInt(req.params.groupId);
        const users = await service.getUsersForGroup(groupId);
        res.json(users);
    };
}
