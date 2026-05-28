package com.da2jobu.deliveryservice.infrastructure.persistence;

import com.da2jobu.deliveryservice.domain.deliveryManager.model.entity.DeliveryManager;
import com.da2jobu.deliveryservice.domain.deliveryManager.model.vo.DeliveryManagerId;
import com.da2jobu.deliveryservice.domain.deliveryManager.model.vo.DeliveryManagerType;
import jakarta.persistence.LockModeType;
import jakarta.persistence.QueryHint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.QueryHints;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface JpaDeliveryManagerRepository extends JpaRepository<DeliveryManager, DeliveryManagerId> {

    // 삭제되지 않은 배송담당자 단건 조회
    Optional<DeliveryManager> findByDeliveryManagerIdAndDeletedAtIsNull(DeliveryManagerId deliveryManagerId);

    // 배송담당자로 등록되어있는지 여부
    boolean existsByUserId_UserId(UUID userId);

    // userId로 배송담당자 단건 조회
    Optional<DeliveryManager> findByUserId_UserIdAndDeletedAtIsNull(UUID userId);

    // 허브 배송 담당자 수 (락 획득)
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @QueryHints({@QueryHint(name = "jakarta.persistence.lock.timeout", value = "3000")})
    List<DeliveryManager> findByTypeAndHubId_HubIdIsNullAndDeletedAtIsNull(DeliveryManagerType type);
    // 업체 배송 담당자 수 (락 획득)
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @QueryHints({@QueryHint(name = "jakarta.persistence.lock.timeout", value = "3000")})
    List<DeliveryManager> findByTypeAndHubId_HubIdAndDeletedAtIsNull(DeliveryManagerType type, UUID hubId);

    // 허브 배송 담당자 최고 순번 조회
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @QueryHints({@QueryHint(name = "jakarta.persistence.lock.timeout", value = "3000")})
    Optional<DeliveryManager> findTopByTypeAndHubId_HubIdIsNullAndDeletedAtIsNullOrderBySeqDesc(DeliveryManagerType type);

    // 업체 배송 담당자 최고 순번 조회
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @QueryHints({@QueryHint(name = "jakarta.persistence.lock.timeout", value = "3000")})
    Optional<DeliveryManager> findTopByTypeAndHubId_HubIdAndDeletedAtIsNullOrderBySeqDesc(DeliveryManagerType type, UUID hubId);
}