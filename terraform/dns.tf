# Route 53 호스팅 영역
resource "aws_route53_zone" "selected" {
  name = var.domain_name
}

# api.<domain> → ALB (443 종단 TLS + 80→301, 인증서는 acm.tf alb_api)
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.selected.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.be_alb.dns_name
    zone_id                = aws_lb.be_alb.zone_id
    evaluate_target_health = true
  }
}
