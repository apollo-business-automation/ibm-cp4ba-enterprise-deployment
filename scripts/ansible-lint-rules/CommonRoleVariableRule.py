from typing import TYPE_CHECKING, Any, Dict, Union
import warnings
import ansiblelint.utils
from ansiblelint.rules import AnsibleLintRule

if TYPE_CHECKING:
    from typing import Optional

    from ansiblelint.file_utils import Lintable

class CommonRoleVariableRule(AnsibleLintRule):
    id: str = 'common_role_variable_rule'
    shortdesc: str = 'Do not allow use of common_ prefix outside of common role in ansible.builtin.set_fact'
    description: str = 'Do not allow use of common_ prefix outside of common role in ansible.builtin.set_fact'
    severity = 'HIGH'
    tags = ['common_role_variable_rule']

    def matchtask(self, task: Dict[str, Any], file: 'Optional[Lintable]' = None) -> Union[bool,str]:
        if 'common' not in str(file):
            if 'action' in task:
                action = task.get('action')
                matches = [ v for k,v in action.items() if 'common_' in k]
                if len(matches) > 0:
                    return True

        return False