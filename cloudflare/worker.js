// da2jobu 폴백 Worker
// - KST 09~21시: 오리진(터널)으로 프록시
// - 그 외 시간 / 오리진 다운: 점검·준비중 페이지 반환
//
// 설정값은 wrangler.toml [vars] 에서 주입 (ORIGIN, OPEN_HOUR, CLOSE_HOUR)

// KST(=UTC+9) 기준 현재 시각. (shifted Date 라 getUTC* 게터로 KST 값을 읽음)
function kstNow() {
  return new Date(Date.now() + 9 * 60 * 60 * 1000);
}

function isOpen(env) {
  const open = parseInt(env.OPEN_HOUR ?? "9", 10);
  const close = parseInt(env.CLOSE_HOUR ?? "21", 10);
  const weekdaysOnly = (env.WEEKDAYS_ONLY ?? "true") === "true";
  const d = kstNow();
  const day = d.getUTCDay(); // 0=일 ... 6=토 (KST 기준)
  if (weekdaysOnly && (day === 0 || day === 6)) return false; // 주말 제외
  const h = d.getUTCHours();
  return h >= open && h < close;
}

function page(title, message, status) {
  const html = `<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  html,body{height:100%;margin:0}
  body{display:flex;align-items:center;justify-content:center;
       font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Apple SD Gothic Neo",sans-serif;
       background:#0f172a;color:#e2e8f0}
  .card{max-width:520px;padding:48px 40px;text-align:center}
  h1{font-size:1.6rem;margin:0 0 12px}
  p{line-height:1.7;color:#94a3b8;margin:6px 0}
  .badge{display:inline-block;margin-bottom:20px;padding:6px 14px;border-radius:999px;
         background:#1e293b;color:#38bdf8;font-size:.85rem}
  .hours{margin-top:24px;font-size:.9rem;color:#cbd5e1}
</style>
</head>
<body>
  <div class="card">
    <div class="badge">da2jobu demo</div>
    <h1>${title}</h1>
    <p>${message}</p>
    <p class="hours">운영 시간: 평일 09:00 ~ 21:00 (KST)</p>
  </div>
</body>
</html>`;
  return new Response(html, {
    status,
    headers: { "content-type": "text/html; charset=utf-8", "retry-after": "3600" },
  });
}

export default {
  async fetch(request, env) {
    // 운영시간 외 → 점검 페이지 (오리진 호출 안 함)
    if (!isOpen(env)) {
      return page("지금은 운영 시간이 아닙니다", "전시용 데모 서버는 평일 09:00~21:00(KST)에만 동작합니다.", 503);
    }

    // 운영시간 → 오리진(터널)으로 프록시
    const origin = env.ORIGIN; // 예: https://origin.example.com
    const url = new URL(request.url);
    const target = new URL(origin);
    target.pathname = url.pathname;
    target.search = url.search;

    try {
      const resp = await fetch(new Request(target.toString(), request));
      // 오리진이 5xx(기동 직후 등)면 준비중 안내로 부드럽게 대체할 수도 있음
      if (resp.status >= 502 && resp.status <= 504) {
        return page("서버를 준비하고 있어요", "기동 중입니다. 잠시 후 새로고침 해주세요.", 503);
      }
      return resp;
    } catch (e) {
      // 오리진 도달 불가(기동 전/터널 끊김)
      return page("서버를 준비하고 있어요", "기동 중입니다. 잠시 후 새로고침 해주세요.", 503);
    }
  },
};
