import { AppDataSource } from "../data-source";
import { UserGroupAccess } from "../entities/UserGroupAccess";
import { UserGroupAccessAuditLog } from "../entities/UserGroupAccessAuditLog";
import { User } from "../entities/User";
import { UserGroup } from "../entities/UserGroup";
import { ActionType } from "../enums/ActionType";

export class UserGroupAccessService {
    private accessRepo = AppDataSource.getRepository(UserGroupAccess);
    private auditRepo = AppDataSource.getRepository(UserGroupAccessAuditLog);
    private userRepo = AppDataSource.getRepository(User);
    private groupRepo = AppDataSource.getRepository(UserGroup);

    async getAll(): Promise<UserGroupAccess[]> {
        return this.accessRepo.find();
    }

    async getById(id: number): Promise<UserGroupAccess | null> {
        return this.accessRepo.findOne({ where: { user_group_access_id: id } });
    }

    /**
     * Get groups for a user.
     * - Global admin: all active groups
     * - Normal user: only assigned groups
     */
    async getGroupsForUser(userId: number) {
        const user = await this.userRepo.findOne({ where: { user_id: userId } });
        if (!user) throw new Error(`User with id ${userId} not found`);

        if (user.is_global_admin) {
            // Fetch all active groups directly for global admin
            const groups = await this.groupRepo.find({ where: { is_active: true } });
            return groups.map(g => ({
                groupId: g.group_id,
                groupName: g.group_name,
                role: "GlobalAdmin"
            }));
        } else {
            // Normal user: fetch assigned groups from UserGroupAccess
            const accessList = await this.accessRepo.find({
                where: {
                    user: { user_id: userId },
                    is_active: true
                },
                relations: ["group", "role"]
            });

            return accessList.map(a => ({
                groupId: a.group.group_id,
                groupName: a.group.group_name,
                role: a.role.role_name
            }));
        }
    }


    async assignRole(
        userId: number,
        groupId: number,
        roleId: number,
        actorUserId: number
    ): Promise<UserGroupAccess> {
        // Fetch user (optional, for validation)
        const user = await this.userRepo.findOne({ where: { user_id: userId } });
        if (!user) throw new Error(`User with id ${userId} not found`);

        // Create access using relation objects
        const access = this.accessRepo.create({
            user: { user_id: userId },
            group: { group_id: groupId },
            role: { role_id: roleId },
            is_active: true
        });
        const savedAccess = await this.accessRepo.save(access);

        // Audit log using IDs
        await this.auditRepo.save({
            actor_user_id: actorUserId,
            target_user_id: userId,
            group_id: groupId,
            action_type: ActionType.ASSIGN_ROLE,
            new_role: roleId.toString(),
        });

        return savedAccess;
    }


    async changeRole(
        accessId: number,
        newRoleId: number,
        actorUserId: number
    ): Promise<UserGroupAccess | null> {
        const access = await this.getById(accessId);
        if (!access) return null;

        const oldRole = access.role.role_id;
        access.role.role_id = newRoleId;
        const updatedAccess = await this.accessRepo.save(access);

        // Audit log
        await this.auditRepo.save({
            actor_user: { user_id: actorUserId },
            target_user: { user_id: access.user.user_id },
            group: { group_id: access.group.group_id },
            action_type: ActionType.CHANGE_ROLE,
            old_role: oldRole.toString(),
            new_role: newRoleId.toString()
        });

        return updatedAccess;
    }

    async removeRole(accessId: number, actorUserId: number): Promise<void> {
        const access = await this.getById(accessId);
        if (!access) return;

        await this.accessRepo.delete(accessId);

        await this.auditRepo.save({
            actor_user: { user_id: actorUserId },
            target_user: { user_id: access.user.user_id },
            group: { group_id: access.group.group_id },
            action_type: ActionType.REMOVE_ROLE,
            old_role: access.role.role_id.toString()
        });
    }
}
