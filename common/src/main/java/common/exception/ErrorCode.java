package common.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum ErrorCode {

    // ── Auth / Token ──────────────────────────────────
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "로그인이 필요합니다."),
    INVALID_TOKEN(HttpStatus.UNAUTHORIZED, "INVALID_TOKEN", "유효하지 않은 토큰입니다."),
    EXPIRED_TOKEN(HttpStatus.UNAUTHORIZED, "EXPIRED_TOKEN", "만료된 토큰입니다. 다시 로그인해 주세요."),
    TOKEN_BLACKLISTED(HttpStatus.UNAUTHORIZED, "TOKEN_BLACKLISTED", "이미 로그아웃된 토큰입니다."),
    INVALID_REFRESH_TOKEN(HttpStatus.UNAUTHORIZED, "INVALID_REFRESH_TOKEN", "유효하지 않은 리프레시 토큰입니다."),
    TOKEN_MISMATCH(HttpStatus.UNAUTHORIZED, "TOKEN_MISMATCH", "토큰 정보가 일치하지 않습니다. 다시 로그인해주세요."),

    // ── User ──────────────────────────────────────────
    USER_NOT_FOUND(HttpStatus.NOT_FOUND, "USER_NOT_FOUND", "존재하지 않는 사용자입니다."),
    DUPLICATE_USERNAME(HttpStatus.CONFLICT, "DUPLICATE_USERNAME", "이미 사용 중인 아이디입니다."),
    DUPLICATE_EMAIL(HttpStatus.CONFLICT, "DUPLICATE_EMAIL", "이미 사용 중인 이메일입니다."),
    INVALID_PASSWORD(HttpStatus.BAD_REQUEST, "INVALID_PASSWORD", "비밀번호가 일치하지 않습니다."),
    PASSWORD_MISMATCH(HttpStatus.BAD_REQUEST, "PASSWORD_MISMATCH", "비밀번호와 비밀번호 확인이 일치하지 않습니다."),
    ALREADY_DELETED(HttpStatus.CONFLICT, "ALREADY_DELETED", "이미 탈퇴한 사용자입니다."),
    WITHDRAWN_USER(HttpStatus.BAD_REQUEST, "WITHDRAWN_USER", "탈퇴한 계정입니다."),
    INVALID_ROLE(HttpStatus.BAD_REQUEST, "INVALID_ROLE", "유효하지 않은 권한 값입니다."),
    LOGIN_FAILED(HttpStatus.UNAUTHORIZED, "LOGIN_FAILED", "아이디 또는 비밀번호가 올바르지 않습니다."),
    CANNOT_DELETE_SELF(HttpStatus.FORBIDDEN,"CANNOT_DELETE_SELF","본인 계정은 삭제할 수 없습니다."),
    CANNOT_UPDATE_ROLE_SELF(HttpStatus.FORBIDDEN,"CANNOT_UPDATE_ROLE_SELF","본인 권한은 변경할 수 없습니다."),
    USER_NOT_APPROVED(HttpStatus.FORBIDDEN, "USER_NOT_APPROVED", "승인되지 않은 사용자입니다."),
    SAME_AS_OLD_PASSWORD(HttpStatus.BAD_REQUEST, "SAME_AS_OLD_PASSWORD", "새 비밀번호는 현재 비밀번호와 달라야 합니다."),

    // ── Common ────────────────────────────────────────
    INVALID_INPUT(HttpStatus.BAD_REQUEST, "INVALID_INPUT", "입력값이 유효하지 않습니다."),
    FORBIDDEN(HttpStatus.FORBIDDEN, "FORBIDDEN", "접근 권한이 없습니다."),
    INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_SERVER_ERROR", "서버 오류가 발생했습니다."),
    INVALID_PAGE_SIZE(HttpStatus.BAD_REQUEST, "INVALID_PAGE_SIZE", "페이지 크기는 10, 30, 50만 가능합니다."),
    INVALID_SORT_BY(HttpStatus.BAD_REQUEST, "INVALID_SORT_BY", "정렬 기준이 올바르지 않습니다."),
    LOCK_TIMEOUT(HttpStatus.CONFLICT, "LOCK_TIMEOUT", "처리 중 잠금 대기 시간을 초과했습니다. 잠시 후 다시 시도해주세요."),

    // ── Company ───────────────────────────────────────
    COMPANY_NOT_FOUND(HttpStatus.NOT_FOUND, "COMPANY_NOT_FOUND", "존재하지 않는 업체입니다."),
    COMPANY_CREATE_FORBIDDEN(HttpStatus.FORBIDDEN, "COMPANY_CREATE_FORBIDDEN", "업체 생성 권한이 없습니다."),
    COMPANY_UPDATE_FORBIDDEN(HttpStatus.FORBIDDEN, "COMPANY_UPDATE_FORBIDDEN", "업체 수정 권한이 없습니다."),
    COMPANY_HUB_MISMATCH(HttpStatus.FORBIDDEN, "COMPANY_HUB_MISMATCH", "담당 허브의 업체만 접근할 수 있습니다."),
    COMPANY_DELETE_FORBIDDEN(HttpStatus.FORBIDDEN, "COMPANY_DELETE_FORBIDDEN", "업체 삭제 권한이 없습니다."),
    COMPANY_HAS_ACTIVE_ORDERS(HttpStatus.CONFLICT, "COMPANY_HAS_ACTIVE_ORDERS", "진행 중인 주문이 있는 업체는 삭제할 수 없습니다."),
    HUB_SERVICE_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "HUB_SERVICE_ERROR", "허브 서비스 호출 중 오류가 발생했습니다."),
    USER_SERVICE_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "USER_SERVICE_ERROR", "유저 서비스 호출 중 오류가 발생했습니다."),
    ORDER_SERVICE_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "ORDER_SERVICE_ERROR", "주문 서비스 호출 중 오류가 발생했습니다."),
    INVALID_ADDRESS(HttpStatus.BAD_REQUEST, "COMPANY_ADDRESS_INVALID", "업체 주소가 올바르지 않습니다."),

    // ── Product ───────────────────────────────────────
    PRODUCT_NOT_FOUND(HttpStatus.NOT_FOUND, "PRODUCT_NOT_FOUND", "존재하지 않는 상품입니다."),
    PRODUCT_CREATE_FORBIDDEN(HttpStatus.FORBIDDEN, "PRODUCT_CREATE_FORBIDDEN", "상품 생성 권한이 없습니다."),
    PRODUCT_UPDATE_FORBIDDEN(HttpStatus.FORBIDDEN, "PRODUCT_UPDATE_FORBIDDEN", "상품 수정 권한이 없습니다."),
    PRODUCT_DELETE_FORBIDDEN(HttpStatus.FORBIDDEN, "PRODUCT_DELETE_FORBIDDEN", "상품 삭제 권한이 없습니다."),
    PRODUCT_COMPANY_HUB_MISMATCH(HttpStatus.BAD_REQUEST, "PRODUCT_COMPANY_HUB_MISMATCH", "업체가 해당 허브에 속하지 않습니다."),
    COMPANY_SERVICE_UNAVAILABLE(HttpStatus.SERVICE_UNAVAILABLE, "COMPANY_SERVICE_UNAVAILABLE", "업체 서비스에 일시적으로 접근할 수 없습니다."),
    USER_SERVICE_UNAVAILABLE(HttpStatus.SERVICE_UNAVAILABLE, "USER_SERVICE_UNAVAILABLE", "사용자 서비스에 일시적으로 접근할 수 없습니다."),

    // ── hub ───────────────────────────────────────
    HUB_NOT_FOUND(HttpStatus.NOT_FOUND, "HUB_NOT_FOUND", "존재하지 않는 허브입니다."),

    // ── Delivery ────────────────────────────────────────
    DELIVERY_NOT_FOUND(HttpStatus.NOT_FOUND, "DELIVERY_NOT_FOUND", "존재하지 않는 배송입니다."),
    DELIVERY_ALREADY_DELETED(HttpStatus.CONFLICT, "DELIVERY_ALREADY_DELETED", "이미 삭제된 배송입니다."),
    INVALID_DELIVERY_STATUS(HttpStatus.BAD_REQUEST, "INVALID_DELIVERY_STATUS", "유효하지 않은 배송 상태입니다."),
    INVALID_DELIVERY_SEARCH_CONDITION(HttpStatus.BAD_REQUEST, "INVALID_DELIVERY_SEARCH_CONDITION", "배송 검색 조건이 올바르지 않습니다."),

    // ── Delivery Route Record────────────────────────────
    DELIVERY_ROUTE_RECORD_NOT_FOUND(HttpStatus.NOT_FOUND, "DELIVERY_ROUTE_RECORD_NOT_FOUND", "존재하지 않는 배송 경로 기록입니다."),
    DELIVERY_ROUTE_RECORD_ALREADY_DELETED(HttpStatus.CONFLICT, "DELIVERY_ROUTE_RECORD_ALREADY_DELETED", "이미 삭제된 배송 경로 기록입니다."),
    INVALID_DELIVERY_ROUTE_STATUS(HttpStatus.BAD_REQUEST, "INVALID_DELIVERY_ROUTE_STATUS", "유효하지 않은 배송 경로 상태입니다."),

    // ── Order ─────────────────────────────────────────────────────────────────
    ORDER_NOT_FOUND(HttpStatus.NOT_FOUND, "ORDER_NOT_FOUND", "존재하지 않는 주문입니다."),
    ORDER_CREATE_FORBIDDEN(HttpStatus.FORBIDDEN, "ORDER_CREATE_FORBIDDEN", "주문 생성 권한이 없습니다."),
    ORDER_UPDATE_FORBIDDEN(HttpStatus.FORBIDDEN, "ORDER_UPDATE_FORBIDDEN", "주문 수정 권한이 없습니다."),
    ORDER_DELETE_FORBIDDEN(HttpStatus.FORBIDDEN, "ORDER_DELETE_FORBIDDEN", "주문 삭제 권한이 없습니다."),
    ORDER_ALREADY_ACCEPTED(HttpStatus.CONFLICT, "ORDER_ALREADY_ACCEPTED", "이미 수락된 주문입니다."),
    ORDER_ALREADY_CANCELLED(HttpStatus.CONFLICT, "ORDER_ALREADY_CANCELLED", "이미 취소된 주문입니다."),
    ORDER_INVALID_STATUS_TRANSITION(HttpStatus.CONFLICT, "ORDER_INVALID_STATUS_TRANSITION", "현재 상태에서 해당 상태로 전환할 수 없습니다."),
    INSUFFICIENT_STOCK(HttpStatus.CONFLICT, "INSUFFICIENT_STOCK", "재고가 부족합니다."),
    INVALID_STOCK_QUANTITY(HttpStatus.BAD_REQUEST, "INVALID_STOCK_QUANTITY", "유효하지 않은 재고 수량입니다."),
    PRODUCT_SERVICE_UNAVAILABLE(HttpStatus.SERVICE_UNAVAILABLE, "PRODUCT_SERVICE_UNAVAILABLE", "상품 서비스에 일시적으로 접근할 수 없습니다."),

    // ── Delivery Manager ─────────────────────────────────────────────────────
    DELIVERY_MANAGER_NOT_FOUND(HttpStatus.NOT_FOUND, "DELIVERY_MANAGER_NOT_FOUND", "존재하지 않는 배송 담당자입니다."),
    DELIVERY_MANAGER_ALREADY_EXISTS(HttpStatus.CONFLICT, "DELIVERY_MANAGER_ALREADY_EXISTS", "이미 등록된 배송 담당자입니다."),
    DELIVERY_MANAGER_LIMIT_EXCEEDED(HttpStatus.CONFLICT, "DELIVERY_MANAGER_LIMIT_EXCEEDED", "해당 유형·소속의 배송 담당자가 최대 인원(10명)에 도달했습니다."),
    DELIVERY_MANAGER_INVALID_ROLE(HttpStatus.BAD_REQUEST, "DELIVERY_MANAGER_INVALID_ROLE", "배송 담당자 권한을 가진 사용자만 등록할 수 있습니다."),
    DELIVERY_MANAGER_HUB_REQUIRED(HttpStatus.BAD_REQUEST, "DELIVERY_MANAGER_HUB_REQUIRED", "업체 배송 담당자는 소속 허브를 지정해야 합니다."),
    DELIVERY_MANAGER_HUB_NOT_ALLOWED(HttpStatus.BAD_REQUEST, "DELIVERY_MANAGER_HUB_NOT_ALLOWED", "허브 배송 담당자는 소속 허브를 지정할 수 없습니다."),
    DELIVERY_MANAGER_ACTIVE(HttpStatus.CONFLICT, "DELIVERY_MANAGER_ACTIVE", "현재 배정되어 있거나 배송 중인 담당자는 삭제할 수 없습니다."),
    DELIVERY_ASSIGNMENT_NOT_FOUND(HttpStatus.NOT_FOUND, "DELIVERY_ASSIGNMENT_NOT_FOUND", "존재하지 않는 배송 배정입니다."),
    NO_AVAILABLE_COMPANY_DELIVERY_MANAGER(HttpStatus.CONFLICT, "NO_AVAILABLE_COMPANY_DELIVERY_MANAGER", "배정 가능한 업체 배송 담당자가 없습니다."),
    ROUTE_OPTIMIZATION_FAILED(HttpStatus.INTERNAL_SERVER_ERROR, "ROUTE_OPTIMIZATION_FAILED", "경로 최적화에 실패했습니다. 제약 완화 후에도 해를 찾지 못했습니다."),
    DELIVERY_MANAGER_HUB_MISMATCH(HttpStatus.FORBIDDEN, "DELIVERY_MANAGER_HUB_MISMATCH", "담당 허브의 배송 담당자만 관리할 수 있습니다."),

    // ── Notification ─────────────────────────────────────────────────────
    NOTIFICATION_NOT_SEND(HttpStatus.BAD_REQUEST, "NOTIFICATION_NOT_SEND", "메세지가 발송될 수 없습니다."),
    NOTIFICATION_NOT_DELETED(HttpStatus.BAD_REQUEST, "NOTIFICATION_NOT_DELETED", "메세지가 삭제될 수 없습니다."),

    // ── AI ─────────────────────────────────────────────────────
    AI_NOT_CREATED(HttpStatus.BAD_REQUEST, "AI_NOT_CREATED", "AI 결과가 생성될 수 없습니다."),
    ;
    private final HttpStatus status;
    private final String code;
    private final String message;
}
