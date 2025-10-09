import { AppDataSource } from "../data-source";
import { UserGroup } from "../entities/UserGroup";
import { GroupAuditLog } from "../entities/GroupAuditLog";
import { UserGroupAccess } from "../entities/UserGroupAccess";
import { User } from "../entities/User";

export class UserGroupService {
    private groupRepo = AppDataSource.getRepository(UserGroup);
    private auditRepo = AppDataSource.getRepository(GroupAuditLog);
    private accessRepo = AppDataSource.getRepository(UserGroupAccess);
    private userRepo = AppDataSource.getRepository(User);

    async getAllGroups(): Promise<UserGroup[]> {
        return this.groupRepo.find();
    }

    async getGroupById(group_id: number): Promise<UserGroup | null> {
        return this.groupRepo.findOne({ where: { group_id } });
    }

    async createGroup(data: Partial<UserGroup>, actorUserId: number): Promise<UserGroup> {
        const group = this.groupRepo.create(data);
        const savedGroup = await this.groupRepo.save(group);

        // Audit log
        await this.auditRepo.save({
            actor_user: { user_id: actorUserId },
            group: savedGroup,
            action_type: "CREATE_GROUP",
            new_value: JSON.stringify(savedGroup)
        });

        return savedGroup;
    }

    async updateGroup(group_id: number, data: Partial<UserGroup>, actorUserId: number): Promise<UserGroup | null> {
        const group = await this.getGroupById(group_id);
        if (!group) return null;

        const oldValue = JSON.stringify(group);
        await this.groupRepo.update(group_id, data);
        const updatedGroup = await this.getGroupById(group_id);

        // Audit log
        await this.auditRepo.save({
            actor_user: { user_id: actorUserId },
            group: updatedGroup!,
            action_type: "UPDATE_GROUP",
            old_value: oldValue,
            new_value: JSON.stringify(updatedGroup)
        });

        return updatedGroup;
    }

    async deactivateGroup(group_id: number, actorUserId: number): Promise<UserGroup | null> {
        return this.updateGroup(group_id, { is_active: false }, actorUserId);
    }

    async getUsersForGroup(groupId: number) {
        const group = await this.groupRepo.findOne({ where: { group_id: groupId } });
        if (!group) throw new Error(`Group with id ${groupId} not found`);

        // 1️⃣ Get all global admins
        const globalAdmins = await this.userRepo.find({ where: { is_global_admin: true, is_active: true } });

        // 2️⃣ Get all users assigned to this group
        const accessList = await this.accessRepo.find({
            where: { group: { group_id: groupId }, is_active: true },
            relations: ["user", "role"]
        });

        // 3️⃣ Combine and remove duplicates if any
        const normalUsers = accessList.map(a => ({
            userId: a.user.user_id,
            username: a.user.username,
            email: a.user.email,
            role: a.role.role_name
        }));

        const adminUsers = globalAdmins.map(u => ({
            userId: u.user_id,
            username: u.username,
            email: u.email,
            role: "GlobalAdmin"
        }));

        // Combine and return
        return [...adminUsers, ...normalUsers];
    }
}
