pub const limine = @import("limine");

const start_marker linksection(".limine_requests_start") = limine.RequestsStartMarker{};
const end_marker linksection(".limine_requests_end") = limine.RequestsEndMarker{};

pub export var base_revision: limine.BaseRevision linksection(".limine_requests") = .init(3);
pub export var framebuffer_request linksection(".limine_requests") = limine.FramebufferRequest{};
pub export var memory_map_request linksection(".limine_requests") = limine.MemoryMapRequest{};
pub export var hhdm_request linksection(".limine_requests") = limine.HhdmRequest{};
pub export var rspd_request linksection(".limine_requests") = limine.RsdpRequest{};
pub export var kernel linksection(".limine_requests") = limine.ExecutableFileRequest{};
