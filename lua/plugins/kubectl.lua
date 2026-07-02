-- ========================================
-- kubectl.nvim: Kubernetes 클러스터 UI
-- ========================================
--
-- manifest 편집(yaml-k8s.lua)과 별개로, 실행 중인 클러스터를
-- Neovim 안에서 직접 조작한다.
--
-- 사용법:
--   <leader>k  → 클러스터 뷰 토글
--   1-6        → 주요 뷰 전환 (pods, deployments, ...)
--   <CR>       → 리소스 드릴다운 (deployment → pod → container)
--   g?         → 뷰별 키맵 도움말
--
-- 주요 기능: 로그 tail, exec 진입, port-forward, rollout restart,
-- context/namespace 전환
--
-- 요구사항: kubectl이 설치되어 있고 kubeconfig가 구성된 머신

return {
  {
    "ramilito/kubectl.nvim",
    version = "2.*",
    dependencies = { "saghen/blink.download" },
    cmd = "Kubectl",
    opts = {},
    keys = {
      {
        "<leader>k",
        function()
          require("kubectl").toggle()
        end,
        desc = "Kubectl: Cluster view",
      },
    },
  },
}
