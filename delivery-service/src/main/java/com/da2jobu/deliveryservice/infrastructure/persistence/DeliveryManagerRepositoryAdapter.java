package com.da2jobu.deliveryservice.infrastructure.persistence;

import com.da2jobu.deliveryservice.domain.deliveryManager.model.entity.DeliveryManager;
import com.da2jobu.deliveryservice.domain.deliveryManager.model.entity.QDeliveryAssignment;
import com.da2jobu.deliveryservice.domain.deliveryManager.model.entity.QDeliveryManager;
import com.da2jobu.deliveryservice.domain.deliveryManager.model.vo.*;
import com.da2jobu.deliveryservice.domain.deliveryManager.repository.DeliveryManagerRepository;
import com.querydsl.core.BooleanBuilder;
import com.querydsl.jpa.JPAExpressions;
import com.querydsl.jpa.impl.JPAQueryFactory;
import jakarta.persistence.LockModeType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RequiredArgsConstructor
public class DeliveryManagerRepositoryAdapter implements DeliveryManagerRepository {

    private final JpaDeliveryManagerRepository jpaDeliveryManagerRepository;
    private final JPAQueryFactory queryFactory;

    @Override
    public DeliveryManager save(DeliveryManager deliveryManager) {
        return jpaDeliveryManagerRepository.save(deliveryManager);
    }

    @Override
    public Optional<DeliveryManager> findById(DeliveryManagerId deliveryManagerId) {
        return jpaDeliveryManagerRepository.findByDeliveryManagerIdAndDeletedAtIsNull(deliveryManagerId);
    }

    @Override
    public boolean existsByUserId(UserId userId) {
        return jpaDeliveryManagerRepository.existsByUserId_UserId(userId.getUserId());
    }

    @Override
    public Optional<DeliveryManager> findByUserId(UserId userId) {
        return jpaDeliveryManagerRepository.findByUserId_UserIdAndDeletedAtIsNull(userId.getUserId());
    }

    @Override
    public long countActiveByTypeAndNullHub(DeliveryManagerType type) {
        return jpaDeliveryManagerRepository.findByTypeAndHubId_HubIdIsNullAndDeletedAtIsNull(type).size();
    }

    @Override
    public long countActiveByTypeAndHub(DeliveryManagerType type, HubId hubId) {
        return jpaDeliveryManagerRepository.findByTypeAndHubId_HubIdAndDeletedAtIsNull(type, hubId.getHubId()).size();
    }

    @Override
    public int findMaxSeqByTypeAndNullHubForUpdate(DeliveryManagerType type) {
        return jpaDeliveryManagerRepository
                .findTopByTypeAndHubId_HubIdIsNullAndDeletedAtIsNullOrderBySeqDesc(type)
                .map(DeliveryManager::getSeq)
                .orElse(0);
    }

    @Override
    public int findMaxSeqByTypeAndHubForUpdate(DeliveryManagerType type, HubId hubId) {
        return jpaDeliveryManagerRepository
                .findTopByTypeAndHubId_HubIdAndDeletedAtIsNullOrderBySeqDesc(type, hubId.getHubId())
                .map(DeliveryManager::getSeq)
                .orElse(0);
    }

    @Override
    public Page<DeliveryManager> search(DeliveryManagerType type, UUID hubId, UUID userId, String userRole, Pageable pageable) {
        QDeliveryManager qDeliveryManager = QDeliveryManager.deliveryManager;
        BooleanBuilder builder = new BooleanBuilder();
        builder.and(qDeliveryManager.deletedAt.isNull());

        if (type != null) {
            builder.and(qDeliveryManager.type.eq(type));
        }
        if (hubId != null) {
            builder.and(qDeliveryManager.hubId.hubId.eq(hubId));
        }
        if ("DELIVERY_MANAGER".equals(userRole)) {
            builder.and(qDeliveryManager.userId.userId.eq(userId));
        }

        List<DeliveryManager> content = queryFactory
                .selectFrom(qDeliveryManager)
                .where(builder)
                .orderBy(qDeliveryManager.createdAt.desc())
                .offset(pageable.getOffset())
                .limit(pageable.getPageSize())
                .fetch();

        Long total = queryFactory
                .select(qDeliveryManager.count())
                .from(qDeliveryManager)
                .where(builder)
                .fetchOne();

        return new PageImpl<>(content, pageable, total == null ? 0L : total);
    }

    @Override
    public List<DeliveryManager> findHubDeliveryManagersWithNoAssignment() {
        QDeliveryManager qDeliveryManager = QDeliveryManager.deliveryManager;
        QDeliveryAssignment qDeliveryAssignment = QDeliveryAssignment.deliveryAssignment;

        return queryFactory
                .selectFrom(qDeliveryManager)
                .where(
                        qDeliveryManager.type.eq(DeliveryManagerType.HUB_DELIVERY),
                        qDeliveryManager.deletedAt.isNull(),
                        JPAExpressions.selectOne()
                                .from(qDeliveryAssignment)
                                .where(qDeliveryAssignment.deliveryManagerId.deliveryManagerId
                                        .eq(qDeliveryManager.deliveryManagerId.deliveryManagerId))
                                .notExists()
                )
                .orderBy(qDeliveryManager.seq.asc())
                .setLockMode(LockModeType.PESSIMISTIC_WRITE)
                .setHint("jakarta.persistence.lock.timeout", 3000)
                .fetch();
    }

    @Override
    public List<DeliveryManager> findAvailableCompanyManagersByHub(HubId hubId) {
        QDeliveryManager manager = QDeliveryManager.deliveryManager;
        QDeliveryAssignment assignment = QDeliveryAssignment.deliveryAssignment;

        return queryFactory
                .selectFrom(manager)
                .where(
                        manager.type.eq(DeliveryManagerType.COMPANY_DELIVERY),
                        manager.hubId.hubId.eq(hubId.getHubId()),
                        manager.deletedAt.isNull(),
                        JPAExpressions
                                .selectOne()
                                .from(assignment)
                                .where(
                                        assignment.deliveryManagerId.eq(manager.deliveryManagerId),
                                        assignment.status.eq(DeliveryAssignmentStatus.ASSIGNED)
                                )
                                .notExists()
                )
                .orderBy(manager.seq.asc())
                .fetch();
    }
}