package com.da2jobu.aiservice;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTag;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.library.freeze.FreezingArchRule;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * CLAUDE.md "서비스 내부 레이어" 규칙 중 코드 구조만 보고 판정할 수 있는 것을 테스트로 옮긴 것.
 *
 * <p>실행: {@code ./gradlew :ai-service:archTest}
 *
 * <p>FreezingArchRule 은 도입 시점의 기존 위반을 {@code archunit_store/} 에 기록해 두고,
 * 그 뒤로는 새로 생긴 위반만 실패시킨다. 기록 파일은 커밋한다.
 */
@ArchTag("arch")
@AnalyzeClasses(packages = "com.da2jobu.aiservice", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureRulesTest {

    // 레이어 의존 방향 — 컨트롤러는 application 만 부르고, 바깥 레이어는 안쪽에서 참조되지 않는다.
    // 표현 계층 폴더 이름은 서비스마다 presentation 또는 interfaces 다.
    @ArchTest
    static final ArchRule layers = FreezingArchRule.freeze(
            layeredArchitecture().consideringOnlyDependenciesInLayers()
                    .withOptionalLayers(true)
                    .layer("Presentation").definedBy("..presentation..", "..interfaces..")
                    .layer("Application").definedBy("..application..")
                    .layer("Domain").definedBy("..domain..")
                    .layer("Infrastructure").definedBy("..infrastructure..")
                    .whereLayer("Presentation").mayNotBeAccessedByAnyLayer()
                    .whereLayer("Application").mayOnlyBeAccessedByLayers("Presentation", "Infrastructure")
                    .whereLayer("Domain").mayOnlyBeAccessedByLayers("Application", "Infrastructure")
                    .whereLayer("Infrastructure").mayNotBeAccessedByAnyLayer());

    // domain 은 바깥 레이어를 모른다.
    @ArchTest
    static final ArchRule domainIsInnermost = FreezingArchRule.freeze(
            noClasses().that().resideInAPackage("..domain..")
                    .should().dependOnClassesThat()
                    .resideInAnyPackage("..infrastructure..", "..presentation..", "..interfaces.."));

    // 예외 처리기는 common 의 GlobalExceptionHandler 하나만 둔다.
    @ArchTest
    static final ArchRule noServiceLevelExceptionHandler = FreezingArchRule.freeze(
            noClasses().should().beAnnotatedWith(RestControllerAdvice.class)
                    .orShould().beAnnotatedWith(ControllerAdvice.class));
}
