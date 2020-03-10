<div class="copyright" >
  {% set current = date(Date.now(), "YYYY") %}
  &copy; {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  <span itemprop="copyrightYear">{{ current }}</span>
  <span class="with-love">
    <i class="fa fa-{{ theme.authoricon }}"></i>
  </span>
  <span class="author" itemprop="copyrightHolder">{{ config.author }}</span>
  <span>&nbsp;
    <a href="http://beian.miit.gov.cn">
      <p style="float:left; height:20px;line-height:20px;margin: 7px 0px 0px 5px; color:#939393;">闽ICP备18023112号</p>
    </a>
  </span>
  <span style="width:300px;margin:0 auto; padding:20px 0;">&nbsp;
		<a target="_blank" href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=35012102500070" >
      <img src="/images/batb.png" style="float:left; padding-top:7px; padding-left:30px;"/>
      <p style="float:left; height:20px;line-height:20px;margin: 7px 0px 0px 5px; color:#939393; padding-right: 80px;">闽公网安备 35012102500070号</p>
    </a>
	</span>
</div>

{% if theme.copyright %}
<div class="powered-by">
  {{ __('footer.powered', '<a class="theme-link" href="https://hexo.io">Hexo</a>') }}
</div>

<div class="theme-info">
  {{ __('footer.theme') }} -
  <a class="theme-link" href="https://github.com/iissnan/hexo-theme-next">
    NexT.{{ theme.scheme }}
  </a>
</div>
{% endif %}
